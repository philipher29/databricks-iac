package tests

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ---------------------------------------------------------------------------------------------------------------------
// INTEGRATION TESTS
// These tests deploy real resources to a Databricks workspace
// Requires: existing workspace, proper authentication
// Set INTEGRATION_TEST=true and DATABRICKS_HOST to run
// ---------------------------------------------------------------------------------------------------------------------

func skipIfNotIntegration(t *testing.T) {
	if os.Getenv("INTEGRATION_TEST") != "true" {
		t.Skip("Skipping integration test. Set INTEGRATION_TEST=true to run.")
	}
	if os.Getenv("DATABRICKS_HOST") == "" {
		t.Skip("Skipping integration test. Set DATABRICKS_HOST to run.")
	}
}

// TestIntegrationGroupCreation tests creating groups in a real workspace
func TestIntegrationGroupCreation(t *testing.T) {
	skipIfNotIntegration(t)
	t.Parallel()

	uniqueID := random.UniqueId()
	workspaceID := os.Getenv("TEST_WORKSPACE_ID")
	require.NotEmpty(t, workspaceID, "TEST_WORKSPACE_ID must be set")

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"workspace_id": workspaceID,
			"groups": map[string]interface{}{
				fmt.Sprintf("test_group_%s", uniqueID): map[string]interface{}{
					"display_name":         fmt.Sprintf("Test Group %s", uniqueID),
					"allow_cluster_create": false,
					"workspace_access":     true,
				},
			},
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Validate outputs
	groups := terraform.OutputMap(t, terraformOptions, "groups")
	assert.NotEmpty(t, groups, "Should create groups")
}

// TestIntegrationClusterPolicyCreation tests creating cluster policies
func TestIntegrationClusterPolicyCreation(t *testing.T) {
	skipIfNotIntegration(t)
	t.Parallel()

	uniqueID := random.UniqueId()
	workspaceID := os.Getenv("TEST_WORKSPACE_ID")
	require.NotEmpty(t, workspaceID)

	policyDefinition := `{
		"autotermination_minutes": {
			"type": "range",
			"minValue": 10,
			"maxValue": 60,
			"defaultValue": 30
		}
	}`

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"workspace_id": workspaceID,
			"cluster_policies": map[string]interface{}{
				fmt.Sprintf("test_policy_%s", uniqueID): map[string]interface{}{
					"definition":  policyDefinition,
					"description": "Test policy for integration testing",
				},
			},
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	policies := terraform.OutputMap(t, terraformOptions, "cluster_policies")
	assert.NotEmpty(t, policies, "Should create cluster policies")
}

// TestIntegrationSecretScopeCreation tests creating secret scopes
func TestIntegrationSecretScopeCreation(t *testing.T) {
	skipIfNotIntegration(t)
	t.Parallel()

	uniqueID := random.UniqueId()
	workspaceID := os.Getenv("TEST_WORKSPACE_ID")
	require.NotEmpty(t, workspaceID)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"workspace_id": workspaceID,
			"secret_scopes": map[string]interface{}{
				fmt.Sprintf("test_scope_%s", uniqueID): map[string]interface{}{
					"initial_manage_principal": "users",
				},
			},
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	scopes := terraform.OutputMap(t, terraformOptions, "secret_scopes")
	assert.NotEmpty(t, scopes, "Should create secret scopes")
}

// TestIntegrationFullConfiguration tests a complete configuration deployment
func TestIntegrationFullConfiguration(t *testing.T) {
	skipIfNotIntegration(t)
	// Not parallel - comprehensive test

	uniqueID := random.UniqueId()
	workspaceID := os.Getenv("TEST_WORKSPACE_ID")
	metastoreID := os.Getenv("TEST_METASTORE_ID")
	accessConnectorID := os.Getenv("TEST_ACCESS_CONNECTOR_ID")
	storageAccountName := os.Getenv("TEST_STORAGE_ACCOUNT")

	require.NotEmpty(t, workspaceID)

	vars := map[string]interface{}{
		"workspace_id": workspaceID,
		"groups": map[string]interface{}{
			fmt.Sprintf("engineers_%s", uniqueID): map[string]interface{}{
				"display_name":         fmt.Sprintf("Engineers %s", uniqueID),
				"allow_cluster_create": true,
				"workspace_access":     true,
			},
			fmt.Sprintf("analysts_%s", uniqueID): map[string]interface{}{
				"display_name":     fmt.Sprintf("Analysts %s", uniqueID),
				"workspace_access": true,
			},
		},
		"cluster_policies": map[string]interface{}{
			fmt.Sprintf("standard_%s", uniqueID): map[string]interface{}{
				"definition": `{"autotermination_minutes":{"type":"fixed","value":30}}`,
			},
		},
		"secret_scopes": map[string]interface{}{
			fmt.Sprintf("scope_%s", uniqueID): map[string]interface{}{
				"initial_manage_principal": "users",
			},
		},
	}

	// Add Unity Catalog resources if metastore available
	if metastoreID != "" && accessConnectorID != "" && storageAccountName != "" {
		vars["unity_catalog_metastore_id"] = metastoreID
		vars["access_connector_id"] = accessConnectorID
		vars["storage_credentials"] = map[string]interface{}{
			fmt.Sprintf("cred_%s", uniqueID): map[string]interface{}{
				"comment": "Test credential",
			},
		}
		vars["external_locations"] = map[string]interface{}{
			fmt.Sprintf("loc_%s", uniqueID): map[string]interface{}{
				"url":             fmt.Sprintf("abfss://test@%s.dfs.core.windows.net/test", storageAccountName),
				"credential_name": fmt.Sprintf("cred_%s", uniqueID),
				"comment":         "Test location",
				"skip_validation": true,
			},
		}
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars:         vars,
		NoColor:      true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Validate all outputs
	groups := terraform.OutputMap(t, terraformOptions, "groups")
	assert.Len(t, groups, 2, "Should create 2 groups")

	policies := terraform.OutputMap(t, terraformOptions, "cluster_policies")
	assert.Len(t, policies, 1, "Should create 1 cluster policy")

	scopes := terraform.OutputMap(t, terraformOptions, "secret_scopes")
	assert.Len(t, scopes, 1, "Should create 1 secret scope")

	// Test idempotency
	planOutput := terraform.Plan(t, terraformOptions)
	assert.Contains(t, planOutput, "No changes", "Should be idempotent")
}

// TestIntegrationIPAccessList tests IP access list creation
func TestIntegrationIPAccessList(t *testing.T) {
	skipIfNotIntegration(t)
	t.Parallel()

	uniqueID := random.UniqueId()
	workspaceID := os.Getenv("TEST_WORKSPACE_ID")
	require.NotEmpty(t, workspaceID)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"workspace_id": workspaceID,
			"ip_access_lists": map[string]interface{}{
				fmt.Sprintf("test_allow_%s", uniqueID): map[string]interface{}{
					"list_type":    "ALLOW",
					"ip_addresses": []string{"10.0.0.0/8", "172.16.0.0/12"},
					"enabled":      true,
				},
			},
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	lists := terraform.OutputMap(t, terraformOptions, "ip_access_lists")
	assert.NotEmpty(t, lists, "Should create IP access lists")
}
