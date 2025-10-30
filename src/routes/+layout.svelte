<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { session } from '$lib/stores/session';
	import favicon from '$lib/assets/favicon.svg';

	let { children } = $props();

	// Derive isLoggedIn from session store
	let isLoggedIn = $derived(!!$session?.auth_token);

	function handleLogout() {
		session.clear();
		goto(resolve('/'));
	}
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

<div class="layout">
	<main class="content">
		{@render children?.()}
	</main>

	{#if isLoggedIn}
		<footer>
			<button class="logout-link" onclick={handleLogout}>Logout</button>
		</footer>
	{/if}
</div>

<style>
	.layout {
		min-height: 100vh;
		display: flex;
		flex-direction: column;
	}

	.content {
		flex: 1;
		max-width: 1200px;
		width: 100%;
		margin: 0 auto;
		padding: 2rem 1rem;
		box-sizing: border-box;
	}

	@media (max-width: 768px) {
		.content {
			padding: 1rem;
			padding-bottom: 5rem;
		}
	}

	footer {
		text-align: center;
		padding: 2rem 1rem;
		margin-top: auto;
		flex-shrink: 0;
	}

	@media (max-width: 768px) {
		footer {
			position: fixed;
			bottom: 0;
			left: 0;
			right: 0;
			width: 100%;
			background: white;
			border-top: 1px solid #eee;
			padding: 1rem;
			z-index: 100;
		}
	}

	.logout-link {
		background: none;
		border: none;
		color: #666;
		font-size: 0.875rem;
		cursor: pointer;
		text-decoration: underline;
		padding: 0;
	}

	.logout-link:hover {
		color: #000;
	}
</style>
