package main

import (
	"fmt"
	"log"

	"github.com/tty8747/goCovid19/cmd/database"
)

func (app *application) insertData() {
	// Insert countries into sql table countries
	for _, elem := range app.cList {
		query := fmt.Sprintf("INSERT INTO `countries`(`code`) VALUES ('%s');", elem)
		log.Println(query)
		if err := database.AddData(query, app.dbSettings); err != nil {
			app.errLog.Fatal(err)
		}
	}

	// Insert dates into sql table dates
	for _, elem := range app.listOfDates {
		query := fmt.Sprintf("INSERT INTO `dates`(`date_value`) VALUES ('%s');", elem)
		log.Println(query)
		if err := database.AddData(query, app.dbSettings); err != nil {
			app.errLog.Fatal(err)
		}
	}

	// Insert cases into sql table cases
	for _, elem := range app.listObj {
		queryCountries := fmt.Sprintf("select id from countries where code='%s';", elem.CountryCode)
		queryDates := fmt.Sprintf("select id from dates where date_value='%s';", elem.DateValue)

		countryId, err := database.ReturnId(queryCountries, app.dbSettings)
		if err != nil {
			app.errLog.Fatal(err)
		}
		dateId, err := database.ReturnId(queryDates, app.dbSettings)
		if err != nil {
			app.errLog.Fatal(err)
		}
		query := fmt.Sprintf("INSERT INTO `cases`(`country_id`,`date_id`,`confirmed`,`deaths`,`stringency_actual`,`stringency`) VALUES ('%d','%d',%d,%d,%f,%f);", countryId, dateId, elem.Confirmed, elem.Deaths, elem.StringencyActual, elem.Stringency)

		log.Println(query)
		if err := database.AddData(query, app.dbSettings); err != nil {
			app.errLog.Fatal(err)
		}
	}
}
