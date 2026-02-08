# Provider Coverage Matrix

Updated: 2026-02-08 03:03:49Z

## Legend
- `Tested`: covered by automated integration scripts in CI.
- `Partial`: implemented but blocked by known runtime/API prerequisites.
- `Known Issue`: implementation bug or invalid behavior observed during tests.
- `Not Tested`: no automated coverage yet.

## Resources

| Resource | Status | Priority | Coverage | Notes |
|---|---|---|---|---|
| `acme` | Tested | P0 | `scripts/registry_integration.sh` | CRUD validated in containerized integration |
| `backend` | Tested | P0 | `scripts/registry_integration.sh` | CRUD validated in containerized integration |
| `backend_acl` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_filter` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_http_after_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_http_check` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_http_error_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_http_request_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_http_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_log_target` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_server` | Tested | P0 | `scripts/registry_integration.sh` | CRUD validated in containerized integration |
| `backend_server_switching_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_server_template` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_stick_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_tcp_check` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_tcp_request_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_tcp_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `cache` | Tested | P0 | `scripts/registry_integration.sh` | CRUD validated in containerized integration |
| `crt_load` | Not Tested | P2 | `-` | Pending automated coverage |
| `crt_store` | Not Tested | P2 | `-` | Pending automated coverage |
| `default` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_acl` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_http_after_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_http_check` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_http_error_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_http_request_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_http_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_log_target` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_quic_initial_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_tcp_check` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_tcp_request_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_tcp_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `fcgi_app` | Not Tested | P2 | `-` | Pending automated coverage |
| `fcgi_app_acl` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend` | Tested | P0 | `scripts/registry_integration.sh` | CRUD validated in containerized integration |
| `frontend_acl` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_backend_switching_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_bind` | Tested | P0 | `scripts/registry_integration.sh` | CRUD validated in containerized integration |
| `frontend_capture` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_filter` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_http_after_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_http_error_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_http_request_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_http_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_log_target` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_quic_initial_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_ssl_front_use` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_tcp_request_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `global_log_target` | Not Tested | P2 | `-` | Pending automated coverage |
| `group` | Tested | P0 | `scripts/registry_integration.sh` | CRUD validated in containerized integration |
| `http_errors_section` | Not Tested | P2 | `-` | Pending automated coverage |
| `log_forward` | Not Tested | P2 | `-` | Pending automated coverage |
| `log_forward_bind` | Not Tested | P2 | `-` | Pending automated coverage |
| `log_forward_dgram_bind` | Not Tested | P2 | `-` | Pending automated coverage |
| `log_forward_log_target` | Not Tested | P2 | `-` | Pending automated coverage |
| `log_profile` | Tested | P0 | `scripts/registry_integration.sh` | CRUD validated in containerized integration |
| `mailer_entry` | Not Tested | P2 | `-` | Pending automated coverage |
| `mailers_section` | Not Tested | P2 | `-` | Pending automated coverage |
| `nameserver` | Tested | P0 | `scripts/registry_integration.sh` | CRUD validated in containerized integration |
| `peer_bind` | Not Tested | P2 | `-` | Pending automated coverage |
| `peer_entry` | Not Tested | P2 | `-` | Pending automated coverage |
| `peer_log_target` | Not Tested | P2 | `-` | Pending automated coverage |
| `peer_section` | Not Tested | P2 | `-` | Pending automated coverage |
| `peer_server` | Not Tested | P2 | `-` | Pending automated coverage |
| `peer_table` | Not Tested | P2 | `-` | Pending automated coverage |
| `program` | Not Tested | P2 | `-` | Pending automated coverage |
| `resolver` | Tested | P0 | `scripts/registry_integration.sh` | CRUD validated in containerized integration |
| `ring` | Not Tested | P2 | `-` | Pending automated coverage |
| `ring_server` | Not Tested | P2 | `-` | Pending automated coverage |
| `user` | Known Issue | P0 | `Attempted in integration` | Create fails with API 422 (username in body required) |
| `userlist` | Tested | P0 | `scripts/registry_integration.sh` | CRUD validated in containerized integration |
| `runtime_acl_entry` | Partial | P1 | `Investigated` | Require pre-existing runtime ACL/map identifiers in HAProxy runtime context |
| `runtime_backend_server` | Tested | P0 | `scripts/registry_runtime_integration.sh` | Create/read/delete validated against runtime API |
| `runtime_map` | Partial | P1 | `Investigated` | Require pre-existing runtime ACL/map identifiers in HAProxy runtime context |
| `runtime_map_entry` | Partial | P1 | `Investigated` | Require pre-existing runtime ACL/map identifiers in HAProxy runtime context |

## Data Sources

| Data Source | Status | Priority | Coverage | Notes |
|---|---|---|---|---|
| `acme` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_acl` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_filter` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_http_after_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_http_check` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_http_error_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_http_request_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_http_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_log_target` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_server` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_server_switching_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_server_template` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_stick_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_tcp_check` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_tcp_request_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `backend_tcp_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `cache` | Known Issue | P0 | `Attempted in integration` | Observed Value Conversion Error in v0.1.7 during data read |
| `crt_load` | Not Tested | P2 | `-` | Pending automated coverage |
| `crt_store` | Not Tested | P2 | `-` | Pending automated coverage |
| `default` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_acl` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_http_after_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_http_check` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_http_error_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_http_request_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_http_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_log_target` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_quic_initial_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_tcp_check` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_tcp_request_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `default_tcp_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `fcgi_app` | Not Tested | P2 | `-` | Pending automated coverage |
| `fcgi_app_acl` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_acl` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_backend_switching_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_bind` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_capture` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_filter` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_http_after_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_http_error_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_http_request_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_http_response_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_log_target` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_quic_initial_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_ssl_front_use` | Not Tested | P2 | `-` | Pending automated coverage |
| `frontend_tcp_request_rule` | Not Tested | P2 | `-` | Pending automated coverage |
| `global` | Not Tested | P2 | `-` | Pending automated coverage |
| `global_log_target` | Not Tested | P2 | `-` | Pending automated coverage |
| `group` | Not Tested | P2 | `-` | Pending automated coverage |
| `http_errors_section` | Not Tested | P2 | `-` | Pending automated coverage |
| `log_forward` | Not Tested | P2 | `-` | Pending automated coverage |
| `log_forward_bind` | Not Tested | P2 | `-` | Pending automated coverage |
| `log_forward_dgram_bind` | Not Tested | P2 | `-` | Pending automated coverage |
| `log_forward_log_target` | Not Tested | P2 | `-` | Pending automated coverage |
| `log_profile` | Known Issue | P0 | `Attempted in integration` | Observed Value Conversion Error in v0.1.7 during data read |
| `mailer_entry` | Not Tested | P2 | `-` | Pending automated coverage |
| `mailers_section` | Not Tested | P2 | `-` | Pending automated coverage |
| `nameserver` | Not Tested | P2 | `-` | Pending automated coverage |
| `peer_bind` | Not Tested | P2 | `-` | Pending automated coverage |
| `peer_entry` | Not Tested | P2 | `-` | Pending automated coverage |
| `peer_log_target` | Not Tested | P2 | `-` | Pending automated coverage |
| `peer_section` | Not Tested | P2 | `-` | Pending automated coverage |
| `peer_server` | Not Tested | P2 | `-` | Pending automated coverage |
| `peer_table` | Not Tested | P2 | `-` | Pending automated coverage |
| `program` | Not Tested | P2 | `-` | Pending automated coverage |
| `resolver` | Not Tested | P2 | `-` | Pending automated coverage |
| `ring` | Not Tested | P2 | `-` | Pending automated coverage |
| `ring_server` | Not Tested | P2 | `-` | Pending automated coverage |
| `trace` | Not Tested | P2 | `-` | Pending automated coverage |
| `user` | Not Tested | P2 | `-` | Pending automated coverage |
| `userlist` | Known Issue | P0 | `Attempted in integration` | Observed Value Conversion Error in v0.1.7 during data read |
| `version` | Not Tested | P2 | `-` | Pending automated coverage |
| `runtime` | Not Tested | P2 | `-` | Runtime data source |
| `runtime_acl` | Not Tested | P2 | `-` | Runtime data source |
| `runtime_acl_entry` | Known Issue | P0 | `Code inspection` | Schema/path mismatch: required parent identifiers not exposed in data source schema |
| `runtime_acme` | Not Tested | P2 | `-` | Runtime data source |
| `runtime_backend_server` | Known Issue | P0 | `Code inspection` | Schema/path mismatch: required parent identifiers not exposed in data source schema |
| `runtime_info` | Not Tested | P2 | `-` | Runtime data source |
| `runtime_map` | Known Issue | P1 | `Code inspection` | Path placeholders require runtime identifiers not modeled as required arguments |
| `runtime_map_entry` | Known Issue | P1 | `Code inspection` | Path placeholders require runtime identifiers not modeled as required arguments |
| `runtime_ssl_ca_file` | Not Tested | P2 | `-` | Runtime data source |
| `runtime_ssl_ca_file_entry` | Not Tested | P2 | `-` | Runtime data source |
| `runtime_ssl_cert` | Not Tested | P2 | `-` | Runtime data source |
| `runtime_ssl_crl_file` | Not Tested | P2 | `-` | Runtime data source |
| `runtime_ssl_crt_list` | Not Tested | P2 | `-` | Runtime data source |
| `runtime_ssl_crt_list_entry` | Not Tested | P2 | `-` | Runtime data source |
| `runtime_stick_table` | Not Tested | P2 | `-` | Runtime data source |
| `runtime_stick_table_entry` | Not Tested | P2 | `-` | Runtime data source |
