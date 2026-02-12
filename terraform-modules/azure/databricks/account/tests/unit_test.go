package tests

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ---------------------------------------------------------------------------------------------------------------------
// PURE UNIT TESTS
// These tests validate module structure and configuration without requiring Terraform or Databricks
// They can run completely offline with no authentication
// ---------------------------------------------------------------------------------------------------------------------

func TestModuleStructure(t *testing.T) {
	t.Parallel()

	moduleDir := "../"
	requiredFiles := []string{
		"versions.tf",
		"variables.tf",
		"outputs.tf",
		"account.tf",
		"version.json",
	}

	for _, file := range requiredFiles {
		filePath := filepath.Join(moduleDir, file)
		_, err := os.Stat(filePath)
		assert.NoError(t, err, "Required file %s should exist", file)
	}
}

func TestModuleVersion(t *testing.T) {
	t.Parallel()

	versionFile := "../version.json"
	data, err := os.ReadFile(versionFile)
	require.NoError(t, err, "Should be able to read version.json")

	var version map[string]interface{}
	err = json.Unmarshal(data, &version)
	require.NoError(t, err, "version.json should be valid JSON")

	assert.Contains(t, version, "module")
	assert.Contains(t, version, "version")
	assert.Contains(t, version, "changelog")

	// Verify module name
	assert.Equal(t, "databricks-account", version["module"])
}

func TestVersionFormat(t *testing.T) {
	t.Parallel()

	versionFile := "../version.json"
	data, err := os.ReadFile(versionFile)
	require.NoError(t, err)

	var version map[string]interface{}
	err = json.Unmarshal(data, &version)
	require.NoError(t, err)

	versionStr, ok := version["version"].(string)
	require.True(t, ok, "version should be a string")
	assert.Regexp(t, `^\d+\.\d+\.\d+$`, versionStr, "Version should follow semver format X.Y.Z")
}

func TestOutputsExist(t *testing.T) {
	t.Parallel()

	expectedOutputs := []string{
		"metastores",
	}

	outputsFile, err := os.ReadFile("../outputs.tf")
	require.NoError(t, err)

	for _, output := range expectedOutputs {
		assert.Contains(t, string(outputsFile), "output \""+output+"\"",
			"outputs.tf should contain output %s", output)
	}
}

func TestVariablesExist(t *testing.T) {
	t.Parallel()

	expectedVariables := []string{
		"metastores",
	}

	variablesFile, err := os.ReadFile("../variables.tf")
	require.NoError(t, err)

	for _, variable := range expectedVariables {
		assert.Contains(t, string(variablesFile), "variable \""+variable+"\"",
			"variables.tf should contain variable %s", variable)
	}
}

func TestProviderVersionsFile(t *testing.T) {
	t.Parallel()

	versionsFile, err := os.ReadFile("../versions.tf")
	require.NoError(t, err)

	content := string(versionsFile)

	// Should require databricks provider
	assert.Contains(t, content, "databricks", "versions.tf should require databricks provider")

	// Should have terraform version constraint
	assert.Contains(t, content, "required_version", "versions.tf should have terraform version constraint")
}
