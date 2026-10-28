<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Subpath support: if APP_URL has a subpath (e.g. /jbi24061), enforce root and scheme
        $appUrl = config('app.url');
        if ($appUrl) {
            $parsedUrl = parse_url($appUrl);
            if (!empty($parsedUrl['path']) && $parsedUrl['path'] !== '/') {
                URL::forceRootUrl($appUrl);
            }
            if (($parsedUrl['scheme'] ?? '') === 'https') {
                URL::forceScheme('https');
            }
        }
    }
}
