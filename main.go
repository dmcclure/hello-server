package main

import (
	"fmt"
	"net/http"
	"os"
	"strings"
)

func sayHelloHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Handling a request to " + r.URL.RequestURI())

	message := r.URL.Path
	message = strings.TrimPrefix(message, "/")
	message = "Hello " + message + "! IMAGE_TAG=" + os.Getenv("IMAGE_TAG") + " ENV_NAME=" + os.Getenv("ENV_NAME")
	w.Write([]byte(message))
}

func main() {
	http.HandleFunc("/", sayHelloHandler)

	fmt.Println("hello-server starting. IMAGE_TAG=" + os.Getenv("IMAGE_TAG") + " ENV_NAME=" + os.Getenv("ENV_NAME") + " BUILD_DATE=" + os.Getenv("BUILD_DATE"))

	if err := http.ListenAndServe(":9090", nil); err != nil {
		panic(err)
	}
}
