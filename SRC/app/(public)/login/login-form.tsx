'use client';

import { useActionState } from 'react';
import { loginAction, type LoginResult } from './actions';

export function LoginForm({ defaultRedirect }: { defaultRedirect?: string }) {
  const [state, formAction, pending] = useActionState<LoginResult | null, FormData>(loginAction, null);

  const emailError = state?.ok === false ? state.fieldErrors?.email : undefined;
  const passwordError = state?.ok === false ? state.fieldErrors?.password : undefined;
  const generalError =
    state?.ok === false && state.code !== 'VALIDATION' ? state.message : undefined;

  return (
    <form action={formAction} className="space-y-5" noValidate>
      {defaultRedirect ? <input type="hidden" name="redirect" value={defaultRedirect} /> : null}

      {generalError ? (
        <div
          role="alert"
          className="rounded-DEFAULT border border-danger/30 bg-danger/5 px-4 py-3 text-body text-danger"
        >
          {generalError}
        </div>
      ) : null}

      <div className="space-y-2">
        <label htmlFor="email" className="block text-body font-medium text-fg">
          이메일
        </label>
        <input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          required
          disabled={pending}
          aria-invalid={emailError ? true : undefined}
          aria-describedby={emailError ? 'email-error' : undefined}
          className="w-full h-12 rounded-DEFAULT border border-divider bg-bg px-4 text-body-lg text-fg placeholder:text-fg-tertiary outline-none transition-colors focus:border-accent focus:ring-2 focus:ring-accent/30 disabled:opacity-50"
          placeholder="you@example.com"
        />
        {emailError ? (
          <p id="email-error" className="text-caption text-danger">
            {emailError}
          </p>
        ) : null}
      </div>

      <div className="space-y-2">
        <label htmlFor="password" className="block text-body font-medium text-fg">
          비밀번호
        </label>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete="current-password"
          required
          disabled={pending}
          aria-invalid={passwordError ? true : undefined}
          aria-describedby={passwordError ? 'password-error' : undefined}
          className="w-full h-12 rounded-DEFAULT border border-divider bg-bg px-4 text-body-lg text-fg placeholder:text-fg-tertiary outline-none transition-colors focus:border-accent focus:ring-2 focus:ring-accent/30 disabled:opacity-50"
        />
        {passwordError ? (
          <p id="password-error" className="text-caption text-danger">
            {passwordError}
          </p>
        ) : null}
      </div>

      <button
        type="submit"
        disabled={pending}
        className="w-full h-12 rounded-pill bg-accent text-fg-inverse text-body-lg font-medium transition-all duration-200 hover:bg-accent-hover hover:-translate-y-0.5 hover:shadow active:translate-y-0 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:transform-none disabled:hover:shadow-none"
      >
        {pending ? '로그인 중...' : '로그인'}
      </button>
    </form>
  );
}
