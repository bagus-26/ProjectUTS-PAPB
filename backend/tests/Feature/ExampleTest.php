<?php

namespace Tests\Feature;

use Tests\TestCase;

class ExampleTest extends TestCase
{
    /**
     * Halaman akar diarahkan ke panel admin.
     */
    public function test_halaman_utama_mengarah_ke_panel_admin(): void
    {
        $this->get('/')->assertRedirect('/admin');
    }
}
