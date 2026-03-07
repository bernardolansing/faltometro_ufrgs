Terraform is an "infrastructure-as-code" provider that allows us to declare how our backend infrastructure is organized
in a much more clear and objective way. The `main.tf` file lists all the resources needed for our application to work.
Terraform produces a state file that must be kept private and safely stored. This project uses Google Cloud Storage for
that purpose.

In order to be able to deploy changes in the backend, you must have installed in your system a service account that has
permission to edit the referred GCS bucket in the `backend` session of `main.tf`.

This Terraform file creates a Google Secrets Manager secret that holds the production database connection string. It
doesn't prompt for the string though, so you have to set it manually in the Google Cloud Console.
