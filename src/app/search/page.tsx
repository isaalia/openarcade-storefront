export default function SearchPage() {
  return (
    <main className="flex-1">
      <section className="relative overflow-hidden border-b border-zinc-800/60 px-6 py-16 grid-pattern">
        <div className="absolute inset-0 bg-gradient-to-br from-teal-500/5 via-transparent to-transparent" />
        <div className="relative mx-auto max-w-7xl">
          <h1 className="font-display text-3xl font-bold tracking-tight text-white sm:text-4xl">
            Search
          </h1>
          <p className="mt-4 text-zinc-400">
            Find games, developers, and more.
          </p>
        </div>
      </section>
      <section className="px-6 py-16">
        <div className="mx-auto max-w-7xl">
          <div className="mx-auto max-w-md">
            <input
              type="search"
              placeholder="Search games..."
              className="w-full rounded-xl border border-zinc-700/60 bg-zinc-900/60 px-4 py-3 text-zinc-100 placeholder-zinc-500 backdrop-blur-sm transition-colors focus:border-amber-500/50 focus:bg-zinc-900/80 focus:outline-none"
              disabled
            />
          </div>
          <p className="mt-8 rounded-2xl border border-dashed border-zinc-700/60 bg-zinc-900/30 py-16 text-center text-zinc-500">
            Search coming soon.
          </p>
        </div>
      </section>
    </main>
  );
}
