package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"time"
)

func main() {
	// Get and parse data:
	//	link := buildLink()
	//	data := getData(link)
	//	c := parseData(data)
	//	fmt.Println(c.Countries)

	app := &application{}

	addr := flag.String("addr", "localhost:4000", "HTTP address")
	flag.Parse()

	infoLog := log.New(os.Stdout, "INFO\t", log.Ldate|log.Ltime)
	errLog := log.New(os.Stderr, "ERROR\t", log.Ldate|log.Ltime|log.Lshortfile)

	srv := &http.Server{
		Addr:     *addr,
		ErrorLog: errLog,
		Handler:  app.routes(),
	}

	infoLog.Printf("Start web-server on %s", *addr)
	err := srv.ListenAndServe()
	errLog.Fatal(err)
}

type application struct {
	errLog           *log.Logger
	infoLog          *log.Logger
	dateFrom, dateTo string
	radioDD          string
	countrySel       string
}

type Countries struct {
	// curl "https://covidtrackerapi.bsg.ox.ac.uk/api/v2/stringency/date-range/2021-11-01/2021-11-12" | jq '.countries[]'
	Countries []string `json:"countries"`
}

func buildLink() string {
	var link string = "https://covidtrackerapi.bsg.ox.ac.uk/api/v2/stringency/date-range"
	tTime := time.Now()
	return fmt.Sprintf("%s/%s-01-01/%s", link, tTime.Format("2006"), tTime.Format("2006-01-02"))
}

func getData(s string) []byte {
	resp, err := http.Get(s)
	if err != nil {
		panic(err)
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}
	return body
}

func parseData(body []byte) Countries {
	var c Countries
	err := json.Unmarshal(body, &c)
	if err != nil {
		panic(err)
	}
	return c
}