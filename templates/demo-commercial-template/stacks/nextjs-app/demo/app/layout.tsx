import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Demo Web",
  description: "Demo workspace starter"
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}