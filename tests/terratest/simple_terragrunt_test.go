package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSimpleTerragruntAccount(t *testing.T) {
	t.Parallel()

	exampleDir := "../../examples/simple/terragrunt/live/prod/aws/us-east-1/my-account/zesty/account"
	tmpDir, err := files.CopyTerraformFolderToTemp(exampleDir, t.Name())
	require.NoError(t, err)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    tmpDir,
		TerraformBinary: "terragrunt",
		NoColor:         true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	kompassValues := terraform.Output(t, terraformOptions, "kompass_values_yaml")
	assert.NotEmpty(t, kompassValues, "kompass_values_yaml output should not be empty")
}

func TestSimpleTerragruntFullE2E(t *testing.T) {
	clusterName := os.Getenv("CLUSTER_NAME")
	require.NotEmpty(t, clusterName, "CLUSTER_NAME environment variable must be set")

	accountDir := "../../examples/simple/terragrunt/live/prod/aws/us-east-1/my-account/zesty/account"
	accountTmpDir, err := files.CopyTerraformFolderToTemp(accountDir, t.Name()+"-account")
	require.NoError(t, err)

	accountOpts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    accountTmpDir,
		TerraformBinary: "terragrunt",
		NoColor:         true,
	})

	defer terraform.Destroy(t, accountOpts)
	terraform.InitAndApply(t, accountOpts)

	kompassValues := terraform.Output(t, accountOpts, "kompass_values_yaml")
	assert.NotEmpty(t, kompassValues, "account layer should output kompass_values_yaml")

	kompassDir := "../../examples/simple/terragrunt/live/prod/aws/us-east-1/my-account/zesty/kompass"
	kompassTmpDir, err := files.CopyTerraformFolderToTemp(kompassDir, t.Name()+"-kompass")
	require.NoError(t, err)

	kompassOpts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    kompassTmpDir,
		TerraformBinary: "terragrunt",
		NoColor:         true,
	})

	defer terraform.Destroy(t, kompassOpts)
	terraform.InitAndApply(t, kompassOpts)
}
