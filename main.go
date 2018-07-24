package main

import (
	"net/http"
	"strings"
)

func sayHelloHandler(w http.ResponseWriter, r *http.Request) {
	message := r.URL.Path
	message = strings.TrimPrefix(message, "/")
	message = "Hello " + message
	w.Write([]byte(message))
}

func main() {
	http.HandleFunc("/", sayHelloHandler)

	if err := http.ListenAndServe(":9090", nil); err != nil {
		panic(err)
	}
}
