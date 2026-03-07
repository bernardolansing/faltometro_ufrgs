# Backend for Faltômetro UFRGS
This codebase provides server support for the Faltômetro UFRGS application. As of now, this server provides the features
that follow:

- Web-scraps the UFRGS student's dashboard, retrieving information on courses and classes.
- Serves this data in a well-structured format.

There are a lot of features to be added in the future, but I'm always short on time :( .

## Technical overview
- Built as an ASP.NET Core MVC web app (C#, .NET version 10). This is not a RESTful API.
- Code is hosted in Google Cloud Platform as a Cloud Run Service.
- PostgreSQL database is provided by Supabase. Supabase Auth is used to authenticate me as an admin, but I'm not certain
I'm going to stick with it in the future.
- Infrastructure is orchestrated by Terraform, but deployments are manual for now.
