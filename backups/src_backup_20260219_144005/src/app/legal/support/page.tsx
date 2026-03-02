import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Mail, MessageSquare } from "lucide-react";
import Link from "next/link";

export default function SupportPage() {
    return (
        <div className="container mx-auto px-4 py-12 max-w-4xl flex flex-col items-center">
            <h1 className="text-3xl font-bold mb-2">Support & Contact</h1>
            <p className="text-muted-foreground mb-10 text-center max-w-lg">
                Need help with your account? Found a bug?
                <br />Our team is here to assist you.
            </p>

            <div className="grid md:grid-cols-2 gap-6 w-full max-w-2xl">
                <Card className="bg-white/5 border-white/10 hover:bg-white/10 transition-colors">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Mail className="w-5 h-5 text-indigo-400" /> Email Support
                        </CardTitle>
                        <CardDescription>
                            For account issues, legal inquiries, or partnership requests.
                        </CardDescription>
                    </CardHeader>
                    <CardContent>
                        <Button asChild className="w-full" variant="secondary">
                            <a href="mailto:support@chartclash.app">Send Email</a>
                        </Button>
                    </CardContent>
                </Card>

                <Card className="bg-white/5 border-white/10 hover:bg-white/10 transition-colors">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <MessageSquare className="w-5 h-5 text-green-400" /> Community
                        </CardTitle>
                        <CardDescription>
                            Ask questions and get help from other users in our community.
                        </CardDescription>
                    </CardHeader>
                    <CardContent>
                        <Link href="/community">
                            <Button className="w-full bg-green-600 hover:bg-green-700">
                                Go to Community
                            </Button>
                        </Link>
                    </CardContent>
                </Card>
            </div>

            <div className="mt-12 text-sm text-gray-500 text-center">
                <p>Operating Hours: Mon-Fri, 9:00 AM - 6:00 PM (UTC)</p>
                <p>Response time usually within 24-48 hours.</p>
            </div>
        </div>
    );
}
