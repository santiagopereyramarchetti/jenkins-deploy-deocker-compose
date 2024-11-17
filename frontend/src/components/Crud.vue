<template>
    <div class="wrapper">
        <div class="index">
            <h2>Lista de Personas</h2>
            <ul v-if="items.length">
                <li v-for="item in items" :key="item.id">
                    ID: {{ item.id }} - Nombre: {{ item.name }}, Apellido: {{ item.surname }}
                    <button @click="editPerson(item)">Editar</button>
                    <button @click="deletePerson(item.id)">Eliminar</button>
                </li>
            </ul>
            <p v-else>No hay personas para mostrar.</p>
        </div>
        <div class="create-edit">
            <h2>Agregar/Editar persona</h2>
            <form @submit.prevent="submitForm">
                <div>
                    <label for="name">Nombre:</label>
                    <input type="text" v-model="formData.name" required />
                </div>
                <div>
                    <label for="name">Apellido:</label>
                    <input type="text" v-model="formData.surname" required />
                </div>
                <div>
                    <label for="name">Edad:</label>
                    <input type="text" v-model="formData.age" required />
                </div>
                <button type="submit">{{ isEditing ? 'Actualizar' : 'Crear' }}</button>
                <button type="button" v-if="isEditing" @click="cancelEdit">Cancelar</button>
            </form>
        </div>
    </div>
</template>

<script setup>
    import { ref, onMounted } from 'vue';
    import axios from 'axios';

    const items = ref([]);
    const formData = ref({ name: '' });
    const isEditing = ref(false);
    let currentId = ref(null);

    const fetchData = async () => {
        try {
            const response = await axios.get('http://192.168.10.40/api/people'); // Hacer una solicitud GET
            items.value = response.data; // Asignar los datos a la referencia
        } catch (error) {
            console.error('Error fetching data:', error); // Manejar errores
        }
    };

    const submitForm = async () => {
        try {
            if (isEditing.value) {
                await axios.put(`http://192.168.10.40/api/people/${currentId.value}`, formData.value);
            } else {
                await axios.post('http://192.168.10.40/api/people', formData.value);
            }
            resetForm();
            fetchData();
        } catch (error) {
            console.error('Error saving person:', error);
        }
    }

    const editPerson = (person) => {
        formData.value.name = person.name;
        formData.value.surname = person.surname;
        formData.value.age = person.age;
        currentId.value = person.id;
        isEditing.value = true;
    };

    const cancelEdit = () => {
        resetForm();
    };

    const deletePerson = async (id) => {
        if (confirm('¿Estás seguro de que deseas eliminar esta persona?')) {
            try {
                await axios.delete(`http://192.168.10.40/api/people/${id}`);
                fetchData();
            } catch (error) {
                console.error('Error deleting person:', error);
            }
        }
    };

    const resetForm = () => {
        formData.value.name = '';
        formData.value.surname = '';
        formData.value.age = '';
        isEditing.value = false;
        currentId.value = null;
    };

    onMounted(fetchData);
</script>

<style lang="scss" scoped>
    .wrapper{
        display: flex;
        flex-direction: column;
        margin-top: 20px;
        width: 100%;
    }
    .w-100 {
        width: 100%;
    }
    .index {
        margin-top: 20px;
        margin-bottom: 20px;
        h4 {
            margin-bottom: 10px;
        }
        button {
            margin-right: 5px;
            margin-left: 5px;
        }
        li{
            margin-top: 7px;
            margin-bottom: 7px;
        }
    }
    .create-edit {
        h4 {
            margin-bottom: 10px;
        }
        input {
            margin-top: 5px;
            margin-bottom: 5px;
        }
        label {
            margin-right: 10px;
        }
        button {
            margin-top: 10px;
            margin-right: 10px;
            width: 75px;
        }
    }
</style>