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
	:global(html) {
		width: 100%;
		box-sizing: border-box;
	}

	:global(body) {
		margin: 0;
		padding: 0;
		width: 100%;
		box-sizing: border-box;
		font-family: monospace;
	}

	:global(*) {
		box-sizing: border-box;
	}

	.layout {
		min-height: 100vh;
		display: flex;
		flex-direction: column;
		width: 100%;
	}

	.content {
		flex: 1;
		max-width: 1200px;
		width: 100%;
		margin: 0 auto;
		padding: 1rem;
		padding-bottom: 5rem;
	}

	footer {
		position: fixed;
		bottom: 0;
		left: 0;
		right: 0;
		width: 100%;
		background: white;
		border-top: 2px solid #000;
		padding: 1rem;
		text-align: center;
	}

	.logout-link {
		background: none;
		border: none;
		color: #000;
		font-size: 0.875rem;
		cursor: pointer;
		text-decoration: underline;
		padding: 0;
		font-family: monospace;
	}
</style>
