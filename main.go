package main

import (
	"net/http"
	"os"
	"strings"
)

func sayHelloHandler(w http.ResponseWriter, r *http.Request) {
	message := r.URL.Path
	message = strings.TrimPrefix(message, "/")
	message = "Hello " + message + "! ENV_NAME: " + os.Getenv("ENV_NAME")
	w.Write([]byte(message))
}

func main() {
	http.HandleFunc("/", sayHelloHandler)

	if err := http.ListenAndServe(":9090", nil); err != nil {
		panic(err)
	}
}
