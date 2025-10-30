<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { session } from '$lib/stores/session';
	import type { Door } from '$lib/types';
	import * as api from '$lib/api-client';

	let doors: Door[] = [];
	let loading = true;
	let error = '';
	let unlocking = '';
	let privateKeys: { login: CryptoKey; signing: CryptoKey } | null = null;

	onMount(async () => {
		session.load();

		if (!$session?.auth_token) {
			goto(resolve('/'));
			return;
		}

		try {
			// Load private keys from session
			privateKeys = await api.loadSessionKeys($session);

			// Fetch doors
			const response = await api.getDoors($session.auth_token);
			const publications = response.mostInvokedPublicationsList || [];

			doors = publications
				.filter((pub) => pub && typeof pub === 'object')
				.map((pub) => {
					const asset = pub.asset || { id: '', name: '', operations: [] };
					const operations = Array.isArray(asset.operations) ? asset.operations : [];

					return {
						publication_id: pub.id,
						name: pub.name || 'Unnamed',
						asset_id: asset.id,
						asset_name: asset.name,
						operations,
						favorite: pub.favorite || false
					};
				});

			loading = false;
		} catch (e) {
			error = e instanceof Error ? e.message : 'An error occurred';
			loading = false;

			// If auth failed, redirect to login
			const errMsg = e instanceof Error ? e.message : '';
			if (errMsg.includes('401') || errMsg.includes('Unauthorized')) {
				session.clear();
				setTimeout(() => goto(resolve('/')), 2000);
			}
		}
	});

	async function handleUnlock(door: Door) {
		if (!$session || !privateKeys) {
			error = 'Not authenticated';
			return;
		}

		if (door.operations.length === 0) {
			error = 'No operations available for this door';
			return;
		}

		const operation = door.operations[0];
		unlocking = operation.id;
		error = '';

		try {
			await api.unlockDoor(
				operation.id,
				$session.auth_token,
				$session.cert_base64,
				privateKeys.login
			);
			// Success feedback
			setTimeout(() => {
				unlocking = '';
			}, 1500);
		} catch (e) {
			error = `Failed to unlock ${door.name}: ${e instanceof Error ? e.message : 'Unknown error'}`;
			unlocking = '';
		}
	}

	function handleLogout() {
		session.clear();
		goto(resolve('/'));
	}
</script>

<main>
	<header>
		<h1>Doors</h1>
		<button on:click={handleLogout}>Logout</button>
	</header>

	{#if error}
		<p class="error">{error}</p>
	{/if}

	{#if loading}
		<p>Loading doors...</p>
	{:else if doors.length === 0}
		<p>No doors available</p>
	{:else}
		<ul>
			{#each doors as door (door.publication_id)}
				<li>
					<div class="door-info">
						<strong>{door.favorite ? '★ ' : ''}{door.name}</strong>
						{#if door.operations.length > 0}
							<span class="operation">{door.operations[0].name}</span>
						{/if}
					</div>
					{#if door.operations.length > 0}
						<button
							on:click={() => handleUnlock(door)}
							disabled={unlocking === door.operations[0].id}
						>
							{unlocking === door.operations[0].id ? 'Unlocking...' : 'Unlock'}
						</button>
					{:else}
						<span class="no-op">No operations</span>
					{/if}
				</li>
			{/each}
		</ul>
	{/if}
</main>

<style>
	main {
		max-width: 600px;
		margin: 2rem auto;
		padding: 1rem;
	}

	header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
	}

	h1 {
		font-size: 1.5rem;
		margin: 0;
	}

	ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	li {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 1rem;
		border: 1px solid #ccc;
		border-radius: 4px;
		margin-bottom: 0.5rem;
	}

	.door-info {
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
	}

	.operation {
		font-size: 0.875rem;
		color: #666;
	}

	.no-op {
		font-size: 0.875rem;
		color: #999;
	}

	button {
		padding: 0.5rem 1rem;
		background: #000;
		color: #fff;
		border: none;
		border-radius: 4px;
		cursor: pointer;
	}

	button:disabled {
		background: #999;
		cursor: not-allowed;
	}

	.error {
		color: #c00;
		margin: 1rem 0;
	}
</style>
