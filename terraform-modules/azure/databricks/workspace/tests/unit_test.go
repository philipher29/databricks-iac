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
// These tests validate module structure and configuration without requiring Terraform or Azure
// They can run completely offline with no authentication
// ---------------------------------------------------------------------------------------------------------------------

// TestModuleStructure validates that all required files exist
func TestModuleStructure(t *testing.T) {
	t.Parallel()

	moduleDir := "../"
	requiredFiles := []string{
		"versions.tf",
		"variables.tf",
		"outputs.tf",
		"workspace.tf",
		"access_connector.tf",
		"private_endpoints.tf",
		"locals.tf",
		"version.json",
	}

	for _, file := range requiredFiles {
		filePath := filepath.Join(moduleDir, file)
		_, err := os.Stat(filePath)
		assert.NoError(t, err, "Required file %s should exist", file)
	}
}

// TestModuleVersion validates version.json is properly formatted
func TestModuleVersion(t *testing.T) {
	t.Parallel()

	versionFile := "../version.json"
	data, err := os.ReadFile(versionFile)
	require.NoError(t, err, "Should be able to read version.json")

	var version map[string]interface{}
	err = json.Unmarshal(data, &version)
	require.NoError(t, err, "version.json should be valid JSON")

	// Check required fields
	assert.Contains(t, version, "module", "version.json should contain 'module' field")
	assert.Contains(t, version, "version", "version.json should contain 'version' field")
	assert.Contains(t, version, "changelog", "version.json should contain 'changelog' field")
	assert.Contains(t, version, "compatibility", "version.json should contain 'compatibility' field")

	// Validate module name
	assert.Equal(t, "databricks-workspace", version["module"], "Module name should be databricks-workspace")
}

// TestOutputsExist verifies all expected outputs are defined
func TestOutputsExist(t *testing.T) {
	t.Parallel()

	expectedOutputs := []string{
		"workspace_id",
		"workspace_url",
		"workspace_resource_id",
		"managed_resource_group_id",
		"managed_resource_group_name",
		"access_connector_id",
		"access_connector_principal_id",
	}

	// Read outputs.tf and check for output blocks
	outputsFile, err := os.ReadFile("../outputs.tf")
	require.NoError(t, err)

	for _, output := range expectedOutputs {
		assert.Contains(t, string(outputsFile), "output \""+output+"\"",
			"outputs.tf should contain output %s", output)
	}
}

// TestVariablesExist verifies all expected variables are defined
func TestVariablesExist(t *testing.T) {
	t.Parallel()

	expectedVariables := []string{
		"name",
		"resource_group_name",
		"location",
		"sku",
		"access_connector",
		"private_endpoints",
		"tags",
	}

	variablesFile, err := os.ReadFile("../variables.tf")
	require.NoError(t, err)

	for _, variable := range expectedVariables {
		assert.Contains(t, string(variablesFile), "variable \""+variable+"\"",
			"variables.tf should contain variable %s", variable)
	}
}

// TestVersionFormat validates the version follows semantic versioning
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

// TestProviderVersionsFile validates versions.tf has required providers
func TestProviderVersionsFile(t *testing.T) {
	t.Parallel()

	versionsFile, err := os.ReadFile("../versions.tf")
	require.NoError(t, err)

	content := string(versionsFile)

	// Should require azurerm provider
	assert.Contains(t, content, "azurerm", "versions.tf should require azurerm provider")
	assert.Contains(t, content, "hashicorp/azurerm", "versions.tf should reference hashicorp/azurerm")

	// Should have terraform version constraint
	assert.Contains(t, content, "required_version", "versions.tf should have terraform version constraint")
}

// TestWorkspaceTfHasRequiredResources validates workspace.tf structure
func TestWorkspaceTfHasRequiredResources(t *testing.T) {
	t.Parallel()

	workspaceFile, err := os.ReadFile("../workspace.tf")
	require.NoError(t, err)

	content := string(workspaceFile)

	// Should contain the main workspace resource
	assert.Contains(t, content, "azurerm_databricks_workspace", "workspace.tf should define databricks workspace resource")
	assert.Contains(t, content, "resource \"azurerm_databricks_workspace\"", "workspace.tf should have workspace resource block")
}

// TestLocalsTfExists validates locals.tf has expected structure
func TestLocalsTfExists(t *testing.T) {
	t.Parallel()

	localsFile, err := os.ReadFile("../locals.tf")
	require.NoError(t, err)

	content := string(localsFile)
	assert.Contains(t, content, "locals {", "locals.tf should have locals block")
}
