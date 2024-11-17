<?php

namespace App\Http\Controllers;

use App\Models\People;
use Illuminate\Http\Request;

class PeopleController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {

        $people = People::all();

        return response()->json($people);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validatedData = $request->validate([
            'name' => 'required|string|max:255',
            'surname' => 'required|string|max:255',
            'age' => 'required|numeric|max:99',
        ]);

        $people = People::create($validatedData);

        return response()->json($people, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(People $person)
    {

        return response()->json($person);
    }


    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, People $person)
    {

        $validatedData = $request->validate([
            'name' => 'required|string|max:255',
            'surname' => 'required|string|max:255',
            'age' => 'required|numeric|max:99',
        ]);

        $person->update($validatedData);

        return response()->json($person);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(People $person)
    {

        $person->delete();

        return response()->json(['message' => 'Person deleted successfully']);
    }
}
