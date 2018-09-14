package main

import (
	"fmt"
	"net/http"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"
)

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

	s := make([]int, 8*1024*1024)
	for i := 0; i < len(s); i++ {
		s[i] = i
	}

	fmt.Printf("Finished allocating %d bytes of memory\n", len(s)*strconv.IntSize)
	time.Sleep(time.Minute * 5)

	message := fmt.Sprintf("Finished consuming %d bytes of memory for 5 minutes", len(s)*strconv.IntSize)
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
