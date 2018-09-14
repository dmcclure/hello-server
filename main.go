package main

import (
	"fmt"
	"net/http"
	"os"
	"runtime"
	"strings"
	"sync"
	"time"
)

var memoryHog [][]uint8
var mutex = &sync.Mutex{}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("OK"))
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Handling request to " + r.URL.RequestURI())

	message := r.URL.Path
	message = strings.TrimPrefix(message, "/hello/")
	message = "Hello " + message + "! IMAGE_TAG=" + os.Getenv("IMAGE_TAG") + " ENV_NAME=" + os.Getenv("ENV_NAME")
	w.Write([]byte(message))
}

func loadCPUHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Handling request to " + r.URL.RequestURI())

	done := make(chan int)

	for i := 0; i < runtime.NumCPU(); i++ {
		go func() {
			for {
				select {
				case <-done:
					return
				default:
				}
			}
		}()
	}

	time.Sleep(time.Minute * 5)
	close(done)

	message := "Finished generating load for 5 minutes"
	w.Write([]byte(message))
}

func loadMemoryHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Handling request to " + r.URL.RequestURI())

	// Add a large slice to the global "memoryHog" slice of slices
	mutex.Lock()
	memoryHog = append(memoryHog, make([]uint8, 64*1024*1024))
	for i := 0; i < len(memoryHog[len(memoryHog)-1]); i++ {
		memoryHog[len(memoryHog)-1][i] = uint8(i % 255)
	}
	message := fmt.Sprintf("Finished consuming %d bytes of memory", len(memoryHog[len(memoryHog)-1]))
	mutex.Unlock()
	w.Write([]byte(message))
}

func main() {
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/hello/", helloHandler)
	http.HandleFunc("/load/cpu", loadCPUHandler)
	http.HandleFunc("/load/memory", loadMemoryHandler)

	fmt.Println("hello-server starting. IMAGE_TAG=" + os.Getenv("IMAGE_TAG") + " ENV_NAME=" + os.Getenv("ENV_NAME") + " BUILD_DATE=" + os.Getenv("BUILD_DATE"))

	if err := http.ListenAndServe(":9090", nil); err != nil {
		panic(err)
	}
}
