<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Throwable;

class ServerStatusController extends Controller
{
    public function index(Request $request)
    {
        // 1. Database Health Check
        $dbStatus = [
            'connected' => false,
            'driver' => config('database.default'),
            'version' => 'Unknown',
            'latency_ms' => 0,
            'error' => null,
        ];

        $startTimer = microtime(true);
        try {
            DB::connection()->getPdo();
            $dbStatus['connected'] = true;
            $dbStatus['version'] = DB::selectOne('select version() as v')?->v ?? 'Connected';
            $dbStatus['latency_ms'] = round((microtime(true) - $startTimer) * 1000, 2);
        } catch (Throwable $e) {
            $dbStatus['error'] = $e->getMessage();
        }

        // 2. Fetch Server Nodes (if table exists)
        $nodes = collect();
        if ($dbStatus['connected']) {
            try {
                $nodes = DB::table('server_nodes')->orderBy('id', 'desc')->limit(20)->get();
            } catch (Throwable $e) {
                // Table might not be migrated yet
            }
        }

        // 3. System & Runtime Environment
        $phpSapi = php_sapi_name();
        $isApache = str_contains($phpSapi, 'apache') || str_contains($request->server('SERVER_SOFTWARE', ''), 'Apache');
        $isDocker = file_exists('/.dockerenv') || file_exists('/run/.containerenv');

        $detectedMode = 'Unknown Environment';
        $modeBadgeClass = 'bg-secondary';
        if ($isDocker) {
            $detectedMode = 'Docker Container (VPS Mode)';
            $modeBadgeClass = 'bg-success';
        } elseif ($isApache) {
            $detectedMode = 'Native Apache (TurnKey LAMP Mode)';
            $modeBadgeClass = 'bg-primary';
        }

        // 4. Ingress & Client IP Detection
        $clientIp = $request->header('cf-connecting-ip') 
            ?? $request->header('x-forwarded-for') 
            ?? $request->ip();

        $ingressGateway = 'Direct Access';
        if ($request->hasHeader('cf-connecting-ip') || $request->hasHeader('cf-ray')) {
            $ingressGateway = 'Cloudflare Zero Trust Edge (Tunnel)';
        } elseif ($request->hasHeader('x-forwarded-for')) {
            $ingressGateway = 'Upstream Reverse Proxy (NPM or Campus Nginx)';
        }

        $memoryUsage = round(memory_get_usage(true) / 1024 / 1024, 2);
        $serverHostname = gethostname() ?: 'unknown-host';
        $subpathPrefix = env('APP_PATH_PREFIX', '');

        return view('dashboard', compact(
            'dbStatus',
            'nodes',
            'phpSapi',
            'isDocker',
            'detectedMode',
            'modeBadgeClass',
            'clientIp',
            'ingressGateway',
            'memoryUsage',
            'serverHostname',
            'subpathPrefix'
        ));
    }

    public function storeNode(Request $request)
    {
        $validated = $request->validate([
            'node_name' => 'required|string|max:100',
            'environment' => 'required|string|max:50',
            'service_role' => 'required|string|max:100',
            'ip_address' => 'required|string|max:45',
            'notes' => 'nullable|string',
        ]);

        try {
            DB::table('server_nodes')->insert([
                'node_name' => $validated['node_name'],
                'environment' => $validated['environment'],
                'service_role' => $validated['service_role'],
                'ip_address' => $validated['ip_address'],
                'notes' => $validated['notes'] ?? '',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            return redirect()->route('dashboard')->with('success', 'Node registered successfully!');
        } catch (Throwable $e) {
            return redirect()->route('dashboard')->with('error', 'Database insert failed: ' . $e->getMessage());
        }
    }

    public function deleteNode(Request $request)
    {
        $id = (int) $request->input('id');
        if ($id > 0) {
            DB::table('server_nodes')->where('id', $id)->delete();
            return redirect()->route('dashboard')->with('info', 'Node record removed.');
        }
        return redirect()->route('dashboard');
    }
}
