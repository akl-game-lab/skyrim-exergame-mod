// webserviceTest.cpp : Defines the entry point for the console application.
//
#include "stdafx.h"
#include <iostream>
#include <iomanip>
#include <ctime>
#include <sstream>
#include <cpprest/http_client.h>
#include <cpprest/filestream.h>

using namespace utility;                    // Common utilities like string conversions
using namespace web;                        // Common features like URIs.
using namespace web::http;                  // Common HTTP functionality
using namespace web::http::client;          // HTTP client features
using namespace concurrency::streams;       // Asynchronous streams

//the exe that this code generates can take 3 or 4 parameters and generates the xml file
//param1 = game id ie. Skyrim
//param2 = username ie. kyu663
//param3 = fromDate ie. 2016-01-0114:20:00
//param4(optional) = toDate ie. 2016-02-2409:28:17 will be current date if unspecified.
int main(int argc, char* argv[])
{
	std::string game = argv[1];
	std::string username = argv[2];
	std::string fromDate = argv[3];
	std::string toDate;
	if (argc == 4) {
		//this code is used to find the current time in yyyymmddhhmmss format
		time_t t = time(0);
		struct tm *lt = localtime(&t);
		std::stringstream currentDate;
		currentDate << std::setfill('0');
		currentDate << std::setw(4) << lt->tm_year + 1900 << "-"
			<< std::setw(2) << lt->tm_mon + 1 << "-"
			<< std::setw(2) << lt->tm_mday
			<< std::setw(2) << lt->tm_hour << ":"
			<< std::setw(2) << lt->tm_min << ":"
			<< std::setw(2) << lt->tm_sec;
		toDate = currentDate.str();
	}
	else {
		toDate = argv[4];
	}


	std::string url = "http://exergaming.isaac.techrus.co.nz/poc_api/get-workout/" + game + "/" + username + "/" + fromDate + "/" + toDate;
	uri fullUri(conversions::to_string_t(url));
	auto fileStream = std::make_shared<ostream>();
	// Open stream to output file.
	pplx::task<void> requestTask = fstream::open_ostream(U("xmlTestfile.txt")).then([=](ostream outFile)
	{
		*fileStream = outFile;

		// Create http_client to send the request.
		http_client client(fullUri);

		// Build request URI and start the request.
		uri_builder builder(U("/search"));
		builder.append_query(U("q"), U("Casablanca CodePlex"));
		return client.request(methods::GET, builder.to_string());
	})

		// Handle response headers arriving.
		.then([=](http_response response)
	{

		// Write response body into the file.
		return response.body().read_to_end(fileStream->streambuf());
	})

		// Close the file stream.
		.then([=](size_t)
	{
		return fileStream->close();
	});

	// Wait for all the outstanding I/O to complete and handle any exceptions
	try
	{
		requestTask.wait();
	}
	catch (const std::exception &e)
	{
	}
	return 0;
}