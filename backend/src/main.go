package main

import (
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()
	r.GET("/", func(c *gin.Context) {
		c.String(200, "Hello from Go backend!")
	})

	port := "8081"
	if envPort := os.Getenv("API_PORT"); envPort != "" {
		port = envPort
	}
	r.Run(":" + port)
}
