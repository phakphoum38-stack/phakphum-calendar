<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Throwable;

class HealthController extends Controller
{
    public function live(Request $request): JsonResponse
    {
        return response()->json([
            'status' => 'ok',
            'service' => config('app.name'),
            'request_id' => $request->attributes->get('request_id'),
        ]);
    }

    public function ready(Request $request): JsonResponse
    {
        try {
            DB::select('select 1');
        } catch (Throwable) {
            return response()->json([
                'status' => 'unavailable',
                'checks' => ['database' => 'failed'],
                'request_id' => $request->attributes->get('request_id'),
            ], 503);
        }

        return response()->json([
            'status' => 'ready',
            'checks' => ['database' => 'ok'],
            'request_id' => $request->attributes->get('request_id'),
        ]);
    }
}
