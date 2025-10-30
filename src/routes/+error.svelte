<script lang="ts">
	import { page } from '$app/stores';
	import { resolve } from '$app/paths';
</script>

<div class="error-page">
	<h1>{$page.status}</h1>
	<p>{$page.error?.message || 'An unexpected error occurred'}</p>
	<a href={resolve('/')}>Go back home</a>
</div>

<style>
	.error-page {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		min-height: 50vh;
		text-align: center;
		padding: 2rem;
	}

	h1 {
		font-size: 3rem;
		margin-bottom: 1rem;
		color: #c00;
	}

	p {
		font-size: 1.25rem;
		margin-bottom: 2rem;
		color: #666;
	}

	a {
		padding: 0.75rem 1.5rem;
		background: #000;
		color: #fff;
		text-decoration: none;
		border-radius: 4px;
		transition: background 0.2s;
	}

	a:hover {
		background: #333;
	}
</style>
