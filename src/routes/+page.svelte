<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { session } from '$lib/stores/session';
	import { decodeJWTPayload } from '$lib/crypto/jwt';
	import * as api from '$lib/api-client';

	let step: 'phone' | 'code' | 'recovery' | 'enrolling' | 'done' = 'phone';
	let phoneNumber = '';
	let verificationCode = '';
	let recoveryKey = '';
	let deviceName = 'Web Browser';
	let verificationCodeId = '';
	let enrollToken = '';
	let userId = '';
	let deviceId = '';
	let recoveryKeyRequired = false;
	let status = '';
	let error = '';
	let loading = false;

	onMount(() => {
		session.load();
		if ($session?.auth_token) {
			goto(resolve('/doors'));
		}
	});

	async function handleRequestCode() {
		if (!phoneNumber) {
			error = 'Phone number is required';
			return;
		}

		loading = true;
		error = '';
		status = 'Requesting verification code...';

		try {
			verificationCodeId = await api.requestVerificationCode(phoneNumber);
			status = 'Verification code sent!';
			step = 'code';
		} catch (e) {
			error = e instanceof Error ? e.message : 'An error occurred';
		} finally {
			loading = false;
		}
	}

	async function handleSubmitCode() {
		if (!verificationCode) {
			error = 'Verification code is required';
			return;
		}

		loading = true;
		error = '';
		status = 'Verifying code...';

		try {
			const response = await api.submitVerificationCode(verificationCode, verificationCodeId);
			enrollToken = response.token;
			recoveryKeyRequired = response.recoveryKeyRequired;

			const payload = decodeJWTPayload(enrollToken);
			userId = payload.jti || payload.sub || '';
			deviceId = payload.deviceId || '';

			status = 'Code verified!';

			if (recoveryKeyRequired) {
				step = 'recovery';
			} else {
				await enrollDeviceAndLogin();
			}
		} catch (e) {
			error = e instanceof Error ? e.message : 'An error occurred';
		} finally {
			loading = false;
		}
	}

	async function handleValidateRecovery() {
		if (!recoveryKey) {
			error = 'Recovery key is required';
			return;
		}

		loading = true;
		error = '';
		status = 'Validating recovery key...';

		try {
			const valid = await api.validateRecoveryKey(recoveryKey, enrollToken);
			if (!valid) {
				throw new Error('Invalid recovery key');
			}
			status = 'Recovery key validated!';
			await enrollDeviceAndLogin();
		} catch (e) {
			error = e instanceof Error ? e.message : 'An error occurred';
			loading = false;
		}
	}

	async function enrollDeviceAndLogin() {
		step = 'enrolling';
		status = 'Enrolling device...';
		error = '';

		try {
			const { certificates, privateKeys, certBase64 } = await api.enrollDevice(
				deviceName,
				recoveryKey || null,
				enrollToken,
				userId,
				deviceId
			);

			status = 'Device enrolled! Logging in...';

			const loginResponse = await api.login(enrollToken, certBase64, privateKeys.login);

			// Update cert from JWT if provided
			const jwtPayload = decodeJWTPayload(loginResponse.auth_token);
			const finalCertBase64 = jwtPayload.publicKeyForLogin || certBase64 || '';

			// Save session
			const sessionData = await api.saveSession(
				loginResponse.auth_token,
				deviceId,
				userId,
				finalCertBase64,
				certificates,
				phoneNumber,
				recoveryKey || null,
				privateKeys
			);

			session.save(sessionData);

			status = 'Login successful!';
			step = 'done';

			setTimeout(() => {
				goto(resolve('/doors'));
			}, 1000);
		} catch (e) {
			error = e instanceof Error ? e.message : 'An error occurred';
			loading = false;
		}
	}
</script>

<main>
	<h1>Accessy Door Control</h1>

	{#if status}
		<p class="status">{status}</p>
	{/if}

	{#if error}
		<p class="error">{error}</p>
	{/if}

	{#if step === 'phone'}
		<form on:submit|preventDefault={handleRequestCode}>
			<label>
				Phone Number
				<input type="tel" bind:value={phoneNumber} required disabled={loading} />
			</label>
			<button type="submit" disabled={loading}>Request Code</button>
		</form>
	{:else if step === 'code'}
		<form on:submit|preventDefault={handleSubmitCode}>
			<label>
				Verification Code
				<input
					type="text"
					inputmode="numeric"
					autocomplete="one-time-code"
					bind:value={verificationCode}
					required
					disabled={loading}
				/>
			</label>
			<button type="submit" disabled={loading}>Submit Code</button>
		</form>
	{:else if step === 'recovery'}
		<form on:submit|preventDefault={handleValidateRecovery}>
			<label>
				Recovery Key
				<input type="text" bind:value={recoveryKey} required disabled={loading} />
			</label>
			<button type="submit" disabled={loading}>Validate Key</button>
		</form>
	{:else if step === 'enrolling'}
		<p>Enrolling device and logging in...</p>
	{:else if step === 'done'}
		<p>Redirecting to doors...</p>
	{/if}
</main>

<style>
	main {
		max-width: 400px;
		margin: 2rem auto;
		padding: 1rem;
	}

	h1 {
		font-size: 1.5rem;
		margin-bottom: 1rem;
	}

	form {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	label {
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
	}

	input {
		padding: 0.5rem;
		border: 1px solid #ccc;
		border-radius: 4px;
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

	.status {
		color: #060;
		margin: 1rem 0;
	}

	.error {
		color: #c00;
		margin: 1rem 0;
	}
</style>
