<template>
  <div class="about">
    <h1 class="w-100">Interactua con el backend</h1>
    <Crud></Crud>
  </div>
</template>

<script setup>
  import Crud from '@/components/Crud.vue';
</script>

<style lang="scss" scoped>
@media (min-width: 1024px) {
  .about {
    min-height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    flex-direction: column;
  }
  .w-100 {
    width: 100%;
  }
}
</style>
