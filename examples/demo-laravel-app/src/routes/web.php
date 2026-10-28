<?php

use App\Http\Controllers\ServerStatusController;
use Illuminate\Support\Facades\Route;

// Subpath-aware route registration
// If APP_PATH_PREFIX is set (e.g. jbi24061 for campus host), register BOTH root and subpath
// so that requests entering via subpath reverse proxy or directly to port 80 are matched!
$prefix = trim((string) env('APP_PATH_PREFIX', ''), '/');

$registerRoutes = function () {
    Route::get('/', [ServerStatusController::class, 'index'])->name('dashboard');
    Route::post('/nodes/create', [ServerStatusController::class, 'storeNode'])->name('nodes.create');
    Route::post('/nodes/delete', [ServerStatusController::class, 'deleteNode'])->name('nodes.delete');
};

if (!empty($prefix)) {
    Route::prefix($prefix)->group($registerRoutes);
}

// Fallback / root registration
$registerRoutes();
