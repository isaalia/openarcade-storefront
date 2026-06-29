export default function ProfilePage() {
  return (
    <main className="flex-1">
      <section className="relative overflow-hidden border-b border-zinc-800/60 px-6 py-16 grid-pattern">
        <div className="absolute inset-0 bg-gradient-to-br from-amber-500/5 via-transparent to-transparent" />
        <div className="relative mx-auto max-w-7xl">
          <h1 className="font-display text-3xl font-bold tracking-tight text-white sm:text-4xl">
            Account
          </h1>
          <p className="mt-4 text-zinc-400">
            Manage your profile and settings.
          </p>
        </div>
      </section>
      <section className="px-6 py-16">
        <div className="mx-auto max-w-7xl">
          <p className="rounded-2xl border border-dashed border-zinc-700/60 bg-zinc-900/30 py-16 text-center text-zinc-500">
            Account settings coming soon.
          </p>
        </div>
      </section>
    </main>
  );
}
