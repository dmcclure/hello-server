package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

func TestServer(t *testing.T) {
	os.Setenv("IMAGE_TAG", "abcdefg")

	req, err := http.NewRequest("GET", "/hello/TestName", nil)
	if err != nil {
		t.Fatal(err)
	}

	resp := httptest.NewRecorder()
	handler := http.HandlerFunc(sayHelloHandler)
	handler.ServeHTTP(resp, req)

	if resp.Code != http.StatusOK {
		t.Fatalf("Received non-200 response code: %d\n", resp.Code)
	}

	expected := "Hello TestName! IMAGE_TAG=abcdefg ENV_NAME=test"
	if resp.Body.String() != expected {
		t.Errorf("Expected: '%s' but received: '%s'\n", expected, resp.Body.String())
	}
}
