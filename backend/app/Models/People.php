<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class People extends Model
{
    use HasFactory;

    protected $table = 'people';

    protected $primaryKey = 'id';

    public function getRouteKeyName()
    {
        return 'id';
    }

    protected $fillable = [
        'name',
        'surname',
        'age',
    ];
}
