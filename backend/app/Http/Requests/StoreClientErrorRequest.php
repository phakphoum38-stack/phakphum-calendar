<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreClientErrorRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'error_code' => ['required', 'string', 'max:100', 'regex:/^[A-Za-z0-9._-]+$/'],
            'category' => ['required', 'string', 'in:import,calendar,report,authentication,network,unknown'],
            'message' => ['required', 'string', 'max:1000'],
            'platform' => ['required', 'string', 'in:web,android,ios,windows,macos,linux,unknown'],
            'app_version' => ['required', 'string', 'max:40'],
            'occurred_at' => ['required', 'date'],
            'access_token' => ['prohibited'],
            'refresh_token' => ['prohibited'],
            'schedule' => ['prohibited'],
            'roster' => ['prohibited'],
        ];
    }
}
