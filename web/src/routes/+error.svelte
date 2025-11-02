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
		padding: 1rem;
		width: 100%;
		max-width: 100%;
	}

	h1 {
		font-size: 2rem;
		margin-bottom: 1rem;
		color: #000;
		font-family: monospace;
		text-transform: uppercase;
		word-break: break-word;
	}

	p {
		font-size: 1rem;
		margin-bottom: 2rem;
		color: #000;
		font-family: monospace;
		word-break: break-word;
	}

	a {
		padding: 0.75rem 1.5rem;
		background: #000;
		color: #fff;
		text-decoration: none;
		border: 2px solid #000;
		font-family: monospace;
		text-transform: uppercase;
		font-weight: bold;
	}

	@media (min-width: 769px) {
		h1 {
			font-size: 3rem;
		}

		p {
			font-size: 1.25rem;
		}
	}
</style>
