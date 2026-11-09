<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        User::query()->updateOrCreate(
            ['email' => 'admin@makanyuk.test'],
            [
                'name' => 'Admin MakanYuk',
                'password' => 'admin12345',
                'is_admin' => true,
                'email_verified_at' => now(),
            ],
        );
    }
}
