schema_version = 1

project {
  license        = "MPL-2.0"
  copyright_year = 2021

  # (OPTIONAL) A list of globs that should not have copyright/license headers.
  # Supports doublestar glob patterns for more flexibility in defining which
  # files or folders should be ignored
  header_ignore = [
    # tests file and generated files
    "hcp-ui-templates/ec2-existing-vpc/main.tf",
    "hcp-ui-templates/ec2/main.tf",
    "hcp-ui-templates/ecs-existing-vpc/main.tf",
    "hcp-ui-templates/ecs/main.tf",
    "hcp-ui-templates/eks-existing-vpc/main.tf",
    "hcp-ui-templates/eks/main.tf",
    "test/hcp/testdata/ec2-existing-vpc.golden",
    "test/hcp/testdata/ec2.golden",
    "test/hcp/testdata/ecs-existing-vpc.golden",
    "test/hcp/testdata/ecs.golden",
    "test/hcp/testdata/eks-existing-vpc.golden",
    "test/hcp/testdata/eks.golden",
  ]
}
