<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ServerLab Pulse - Laravel Infrastructure Validator</title>
    <!-- Bootstrap 5 CSS via CDN (zero compilation required) -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <style>
        body { background-color: #f4f6f9; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
        .hero-banner { background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%); color: #fff; padding: 2rem 0; margin-bottom: 2rem; border-bottom: 3px solid #3b82f6; }
        .stat-card { border: none; border-radius: 0.75rem; transition: transform 0.15s ease, box-shadow 0.15s ease; }
        .stat-card:hover { transform: translateY(-2px); box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); }
    </style>
</head>
<body>

    <!-- Header Navigation -->
    <header class="hero-banner shadow-sm">
        <div class="container">
            <div class="d-flex flex-wrap align-items-center justify-content-between gap-3">
                <div>
                    <h1 class="h3 mb-1 fw-bold"><i class="bi bi-activity text-info me-2"></i>ServerLab Pulse</h1>
                    <p class="mb-0 text-light opacity-75 small">Laravel 11+ Diagnostic & Infrastructure Suite</p>
                </div>
                <div class="d-flex align-items-center gap-2">
                    <span class="badge {{ $modeBadgeClass }} px-3 py-2 fs-6 rounded-pill shadow-sm">
                        <i class="bi bi-cpu me-1"></i>{{ $detectedMode }}
                    </span>
                    <span class="badge bg-dark border border-secondary text-info px-3 py-2 fs-6 rounded-pill">
                        <i class="bi bi-diagram-3 me-1"></i>{{ $serverHostname }}
                    </span>
                </div>
            </div>
        </div>
    </header>

    <main class="container mb-5">

        @if(session('success'))
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <i class="bi bi-check-circle-fill me-2"></i>{{ session('success') }}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        @endif

        @if(session('info'))
            <div class="alert alert-info alert-dismissible fade show" role="alert">
                <i class="bi bi-info-circle-fill me-2"></i>{{ session('info') }}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        @endif

        @if(session('error'))
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <i class="bi bi-exclamation-triangle-fill me-2"></i>{{ session('error') }}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        @endif

        <!-- Diagnostic Metrics Grid -->
        <div class="row g-3 mb-4">
            
            <!-- Runtime Mode Card -->
            <div class="col-md-3 col-sm-6">
                <div class="card stat-card shadow-sm h-100 p-3">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <span class="text-muted small fw-semibold text-uppercase">Runtime SAPI</span>
                        <i class="bi bi-layers text-primary fs-4"></i>
                    </div>
                    <div class="fs-5 fw-bold text-dark">{{ $phpSapi }}</div>
                    <small class="text-muted">Dockerized: <strong>{{ $isDocker ? 'YES' : 'NO' }}</strong></small>
                </div>
            </div>

            <!-- Ingress Gateway -->
            <div class="col-md-3 col-sm-6">
                <div class="card stat-card shadow-sm h-100 p-3">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <span class="text-muted small fw-semibold text-uppercase">Ingress Gateway</span>
                        <i class="bi bi-cloud-check text-info fs-4"></i>
                    </div>
                    <div class="fs-6 fw-bold text-truncate text-dark" title="{{ $ingressGateway }}">
                        {{ $ingressGateway }}
                    </div>
                    <small class="text-muted text-truncate">Client: {{ $clientIp }}</small>
                </div>
            </div>

            <!-- Database Status Card -->
            <div class="col-md-3 col-sm-6">
                <div class="card stat-card shadow-sm h-100 p-3">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <span class="text-muted small fw-semibold text-uppercase">Database Health</span>
                        <i class="bi {{ $dbStatus['connected'] ? 'bi-database-check text-success' : 'bi-database-x text-danger' }} fs-4"></i>
                    </div>
                    @if($dbStatus['connected'])
                        <div class="fs-5 fw-bold text-success">Connected ({{ $dbStatus['latency_ms'] }} ms)</div>
                        <small class="text-muted text-truncate">{{ $dbStatus['version'] }}</small>
                    @else
                        <div class="fs-6 fw-bold text-danger">Disconnected</div>
                        <small class="text-danger text-truncate" title="{{ $dbStatus['error'] }}">
                            {{ Str::limit($dbStatus['error'], 28) }}
                        </small>
                    @endif
                </div>
            </div>

            <!-- Routing & Prefix Status -->
            <div class="col-md-3 col-sm-6">
                <div class="card stat-card shadow-sm h-100 p-3">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <span class="text-muted small fw-semibold text-uppercase">Subpath Prefix</span>
                        <i class="bi bi-signpost-split text-warning fs-4"></i>
                    </div>
                    <div class="fs-5 fw-bold text-dark">
                        {{ $subpathPrefix ? '/' . $subpathPrefix : '/ (Root Domain)' }}
                    </div>
                    <small class="text-muted">Laravel Framework Engine</small>
                </div>
            </div>

        </div>

        <!-- Registry & Architecture Info Grid -->
        <div class="row g-4 mb-4">
            <div class="col-lg-8">
                <div class="card shadow-sm border-0 rounded-3 h-100">
                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                        <h5 class="card-title mb-0 fw-bold"><i class="bi bi-hdd-network me-2 text-primary"></i>Server Node Registry (Database Verification)</h5>
                        <button class="btn btn-sm btn-primary" data-bs-toggle="modal" data-bs-target="#addNodeModal">
                            <i class="bi bi-plus-lg me-1"></i>Register Node
                        </button>
                    </div>
                    <div class="card-body p-0">
                        @if(empty($nodes) || (is_countable($nodes) && count($nodes) === 0))
                            <div class="text-center py-5">
                                <i class="bi bi-inbox text-muted display-4"></i>
                                <p class="text-muted mt-2">No server node records found in database.</p>
                                @if(!$dbStatus['connected'])
                                    <div class="alert alert-warning d-inline-block text-start small">
                                        <i class="bi bi-exclamation-triangle-fill me-1"></i>
                                        Please import <code>database/schema.sql</code> using Adminer or Webmin!
                                    </div>
                                @else
                                    <button class="btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#addNodeModal">Add First Node</button>
                                @endif
                            </div>
                        @else
                            <div class="table-responsive">
                                <table class="table table-hover align-middle mb-0">
                                    <thead class="table-light">
                                        <tr>
                                            <th>Node Name</th>
                                            <th>Environment</th>
                                            <th>Role</th>
                                            <th>IP Address</th>
                                            <th>Registered</th>
                                            <th class="text-end">Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @foreach($nodes as $node)
                                            <tr>
                                                <td class="fw-semibold text-primary">
                                                    <i class="bi bi-server me-1"></i>{{ $node->node_name }}
                                                </td>
                                                <td><span class="badge bg-secondary">{{ $node->environment }}</span></td>
                                                <td>{{ $node->service_role }}</td>
                                                <td><code>{{ $node->ip_address }}</code></td>
                                                <td class="small text-muted">{{ substr($node->created_at, 0, 16) }}</td>
                                                <td class="text-end">
                                                    <form method="POST" action="{{ route('nodes.delete') }}" class="d-inline" onsubmit="return confirm('Delete this node?');">
                                                        @csrf
                                                        <input type="hidden" name="id" value="{{ $node->id }}">
                                                        <button type="submit" class="btn btn-sm btn-outline-danger border-0">
                                                            <i class="bi bi-trash"></i>
                                                        </button>
                                                    </form>
                                                </td>
                                            </tr>
                                        @endforeach
                                    </tbody>
                                </table>
                            </div>
                        @endif
                    </div>
                </div>
            </div>

            <!-- Architecture Info Sidebar -->
            <div class="col-lg-4">
                <div class="card shadow-sm border-0 rounded-3 mb-3">
                    <div class="card-header bg-white py-3">
                        <h6 class="card-title mb-0 fw-bold"><i class="bi bi-shield-check me-2 text-success"></i>Infrastructure Verification</h6>
                    </div>
                    <div class="card-body small">
                        <ul class="list-unstyled mb-0">
                            <li class="mb-2 pb-2 border-bottom d-flex justify-content-between">
                                <span class="text-muted">Framework:</span>
                                <strong>Laravel {{ app()->version() }}</strong>
                            </li>
                            <li class="mb-2 pb-2 border-bottom d-flex justify-content-between">
                                <span class="text-muted">PHP Version:</span>
                                <strong>PHP {{ PHP_VERSION }}</strong>
                            </li>
                            <li class="mb-2 pb-2 border-bottom d-flex justify-content-between">
                                <span class="text-muted">Memory Allocated:</span>
                                <strong>{{ $memoryUsage }} MB</strong>
                            </li>
                            <li class="d-flex justify-content-between">
                                <span class="text-muted">Active Host Port:</span>
                                <strong>{{ request()->server('SERVER_PORT', '80') }}</strong>
                            </li>
                        </ul>
                    </div>
                </div>

                <div class="card bg-primary text-white shadow-sm border-0 rounded-3">
                    <div class="card-body p-3">
                        <h6 class="fw-bold"><i class="bi bi-lightbulb-fill me-1"></i>Track Verification Checklist</h6>
                        <p class="small mb-2 opacity-90">
                            <strong>Track 1 (Webmin/Adminer):</strong> Upload project zip to <code>/var/www/laravel</code>, set permissions on <code>storage</code>, import <code>database/schema.sql</code> via Adminer.
                        </p>
                        <p class="small mb-0 opacity-90">
                            <strong>Track 2 (Docker VPS):</strong> Disable Apache & MariaDB, run <code>compose.yaml</code> on <code>infra_network</code>, configure NPM reverse proxy host.
                        </p>
                    </div>
                </div>
            </div>
        </div>

    </main>

    <!-- Modal: Register Server Node -->
    <div class="modal fade" id="addNodeModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <form method="POST" action="{{ route('nodes.create') }}">
                    @csrf
                    <div class="modal-header">
                        <h5 class="modal-title fw-bold"><i class="bi bi-plus-circle me-2"></i>Register Server Node</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label small fw-semibold">Node Name</label>
                            <input type="text" name="node_name" class="form-control" placeholder="e.g. laravel-worker-01" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-semibold">Environment</label>
                            <select name="environment" class="form-select">
                                <option value="TurnKey Debian 12">TurnKey Debian 12 (Campus)</option>
                                <option value="Docker Container">Docker Container</option>
                                <option value="Staging">Staging</option>
                                <option value="Production">Production</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-semibold">Service Role</label>
                            <input type="text" name="service_role" class="form-control" placeholder="e.g. Reverse Proxy / Web App" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-semibold">IP Address</label>
                            <input type="text" name="ip_address" class="form-control" placeholder="e.g. 192.168.11.16 or 172.20.0.5" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-semibold">Notes</label>
                            <textarea name="notes" class="form-control" rows="2" placeholder="Optional notes..."></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary"><i class="bi bi-save me-1"></i>Save Node</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Bootstrap 5 Bundle JS via CDN -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
