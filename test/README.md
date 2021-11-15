### Module Acceptance Tests

These tests run Terraform code against real infrastructure. They are designed to
test out this modules provided examples.

#### Instructions

There are two different sets of tests in this directory:
1. `examples`: Integration-level tests that ensure the examples are working as expected
2. `hcp`: Unit tests ensuring that the HCP UI templates do not change
   unintentionally

Running the `hcp` suite of tests requires no outside setup. Run this within the
test/ directory:
```
go test ./hcp
```

To update the HCP unit tests, run this command and the golden files will be
updated with any changes made to the templates:
```
go test ./hcp -update
```

Running the example tests requires AWS and HCP credentials, make sure to set up those as
environment variables.

To run the tests, run this within the test/ directory:
```
go test ./examples -v -timeout 1h
```
