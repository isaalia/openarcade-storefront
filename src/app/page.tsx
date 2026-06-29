import Link from "next/link";

export default function Home() {
  return (
    <main className="flex-1">
      {/* Hero Section */}
      <section className="relative overflow-hidden border-b border-zinc-800/60 grid-pattern">
        <div className="absolute inset-0 bg-gradient-to-br from-amber-500/10 via-transparent 40% to-transparent" />
        <div className="absolute inset-0 bg-gradient-to-tl from-teal-500/8 via-transparent 50% to-transparent" />
        <div className="absolute -top-1/2 -right-1/4 h-[120%] w-[80%] rounded-full bg-amber-500/15 blur-[120px]" />
        <div className="absolute -bottom-1/4 -left-1/4 h-[80%] w-[60%] rounded-full bg-teal-500/10 blur-[100px] animate-[orb-pulse_8s_ease-in-out_infinite]" />
        <div className="absolute top-1/4 right-1/3 h-64 w-64 rounded-full bg-amber-400/5 blur-[80px]" />
        <div className="relative mx-auto max-w-4xl px-6 py-28 text-center sm:py-40">
          <h1 className="font-display text-5xl font-bold tracking-tight text-white sm:text-6xl md:text-7xl lg:text-8xl">
            Indie games,{" "}
            <span className="animate-gradient-text bg-gradient-to-r from-amber-400 via-amber-300 to-teal-400 bg-clip-text text-transparent">
              your way
            </span>
          </h1>
          <p className="mx-auto mt-8 max-w-xl text-lg leading-relaxed text-zinc-400 sm:text-xl">
            Discover, buy, and play games from independent developers. No walled gardens. No gatekeepers.
          </p>
          <div className="mt-14 flex flex-wrap justify-center gap-4">
            <Link
              href="/explore"
              className="rounded-xl bg-amber-500 px-10 py-4 font-semibold text-zinc-950 shadow-lg shadow-amber-500/25 transition-all hover:bg-amber-400 hover:shadow-amber-500/40 hover:scale-[1.02]"
            >
              Explore games
            </Link>
            <Link
              href="/store"
              className="rounded-xl border border-zinc-600/80 bg-zinc-900/40 px-10 py-4 font-semibold text-zinc-300 backdrop-blur-sm transition-all hover:border-amber-500/50 hover:bg-zinc-800/60 hover:text-white"
            >
              Browse store
            </Link>
          </div>
        </div>
      </section>

      {/* Discover Section */}
      <section className="relative px-6 py-16">
        <div className="absolute inset-0 grid-pattern opacity-50" aria-hidden="true" />
        <div className="relative mx-auto max-w-7xl space-y-12">
          <h2 className="font-display text-2xl font-semibold text-white">Discover games</h2>
          <p className="rounded-2xl border border-dashed border-zinc-700/60 bg-zinc-900/30 py-16 text-center text-zinc-500">
            No games yet. Check back soon.
          </p>
        </div>
      </section>
    </main>
  );
}
