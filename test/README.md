### Module Acceptance Tests

These tests run Terraform code against real infrastructure. They are designed to
test out this modules provided examples.

#### Instructions

Running the tests requires AWS and HCP credentials, make sure to set up those as
environment variables.

To run the tests, run this within the test/ directory:
```
go test -v -timeout 30m
```
