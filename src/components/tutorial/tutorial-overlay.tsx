"use client";

import { useEffect, useState, useRef } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { X, ArrowRight, Check } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface Step {
    targetId: string;
    title: string;
    content: string;
    position?: "top" | "bottom" | "left" | "right";
}

const STEPS: Step[] = [
    {
        targetId: "tutorial-market-select",
        title: "Step 1: Market",
        content: "Choose the asset you want to trade. Each market resolves on a fixed round schedule.",
        position: "bottom"
    },
    {
        targetId: "tutorial-bet",
        title: "Step 2: Bet Amount",
        content: "Enter the USDT amount you want to stake from your contract balance.",
        position: "top"
    },
    {
        targetId: "tutorial-wallet-connect",
        title: "Step 3: Wallet Check",
        content: "Connect MetaMask and make sure your contract balance is funded before you bet.",
        position: "top"
    },
    {
        targetId: "tutorial-direction",
        title: "Step 4: Long or Short",
        content: "Pick the side you want to back. Once the transaction confirms, the position is locked for that round.",
        position: "top"
    },
    {
        targetId: "tutorial-active-tab",
        title: "Step 5: Track Live Bets",
        content: "Your open positions appear in the Active tab until the market settles.",
        position: "top"
    },
    {
        targetId: "tutorial-history-tab",
        title: "Step 6: Review History",
        content: "Settled rounds move into History with mirrored win, loss, or refund outcomes.",
        position: "top"
    },
    {
        targetId: "tutorial-all-history",
        title: "Step 7: Full Ledger",
        content: "Open the full history page to inspect entry price, close price, and final PnL.",
        position: "top"
    },
    {
        targetId: "tutorial-leaderboard",
        title: "Step 8: Leaderboard",
        content: "Compare your net PnL and hit rate against other traders on the live board.",
        position: "bottom"
    }
];

export function TutorialOverlay() {
    const [currentStep, setCurrentStep] = useState(0);
    const [isVisible, setIsVisible] = useState(false);
    const [rect, setRect] = useState<DOMRect | null>(null);

    // Custom Event Listener for Manual Trigger
    useEffect(() => {
        const handleManualTrigger = () => {
            setCurrentStep(0);
            setIsVisible(true);
        };

        window.addEventListener("trigger-tutorial", handleManualTrigger);
        return () => window.removeEventListener("trigger-tutorial", handleManualTrigger);
    }, []);

    // Update rect when step changes
    useEffect(() => {
        if (!isVisible) return;

        const updatePosition = () => {
            const step = STEPS[currentStep];
            const element = document.getElementById(step.targetId);
            if (element) {
                const newRect = element.getBoundingClientRect();
                // Check if rect is valid
                if (newRect.width > 0 && newRect.height > 0) {
                    setRect(newRect);
                    // Scroll into view if needed
                    element.scrollIntoView({ behavior: "smooth", block: "center" });
                }
            }
        };

        // Initial update
        setTimeout(updatePosition, 100); // Slight delay for scroll/render

        // Listener for resize/scroll
        window.addEventListener("resize", updatePosition);
        window.addEventListener("scroll", updatePosition);

        return () => {
            window.removeEventListener("resize", updatePosition);
            window.removeEventListener("scroll", updatePosition);
        };
    }, [currentStep, isVisible]);

    const handleNext = () => {
        if (currentStep < STEPS.length - 1) {
            setCurrentStep(currentStep + 1);
        } else {
            completeTutorial();
        }
    };

    const skipTutorial = () => {
        completeTutorial();
    };

    const completeTutorial = () => {
        setIsVisible(false);
        localStorage.setItem("chartclash_tutorial_completed", "true");
    };

    if (!isVisible) return null;

    const step = STEPS[currentStep];

    return (
        <AnimatePresence>
            {isVisible && (
                <div className="fixed inset-0 z-[100] overflow-hidden">
                    {/* Backdrop with SVG Mask for Spotlight Effect */}
                    <div className="absolute inset-0 w-full h-full pointer-events-none">
                        <svg className="w-full h-full">
                            <defs>
                                <mask id="spotlight-mask">
                                    <rect x="0" y="0" width="100%" height="100%" fill="white" />
                                    {rect && (
                                        <rect
                                            x={rect.left - 4}
                                            y={rect.top - 4}
                                            width={rect.width + 8}
                                            height={rect.height + 8}
                                            rx="8"
                                            fill="black"
                                        />
                                    )}
                                </mask>
                            </defs>
                            <rect
                                width="100%"
                                height="100%"
                                fill="rgba(0,0,0,0.75)"
                                mask="url(#spotlight-mask)"
                            />
                        </svg>
                    </div>

                    {/* Spotlight Border Animation */}
                    {rect && (
                        <motion.div
                            className="absolute pointer-events-none border-2 border-primary rounded-lg shadow-[0_0_30px_rgba(16,185,129,0.5)] z-[101]"
                            initial={false}
                            animate={{
                                top: rect.top - 4,
                                left: rect.left - 4,
                                width: rect.width + 8,
                                height: rect.height + 8
                            }}
                            transition={{ type: "spring", stiffness: 300, damping: 30 }}
                        />
                    )}

                    {/* Tooltip Card */}
                    {rect && (
                        <motion.div
                            className={cn(
                                "absolute z-[102] w-72 bg-card border border-white/10 rounded-xl shadow-2xl p-4",
                                // Simple positioning logic
                                step.position === "bottom" && "mt-4",
                                step.position === "top" && "mb-4"
                            )}
                            style={{
                                top: step.position === "bottom" ? rect.bottom + 12 : undefined,
                                bottom: step.position === "top" ? window.innerHeight - rect.top + 12 : undefined,
                                left: Math.max(16, Math.min(rect.left, window.innerWidth - 300)) // Keep within screen
                            }}
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: 10 }}
                            key={currentStep}
                        >
                            <div className="flex justify-between items-start mb-2">
                                <h3 className="font-bold text-white text-sm">{step.title}</h3>
                                <button onClick={skipTutorial} className="text-muted-foreground hover:text-white">
                                    <X className="w-4 h-4" />
                                </button>
                            </div>
                            <p className="text-xs text-muted-foreground mb-4 leading-relaxed">
                                {step.content}
                            </p>
                            <div className="flex justify-between items-center">
                                <span className="text-[10px] text-muted-foreground font-mono">
                                    {currentStep + 1} / {STEPS.length}
                                </span>
                                <Button size="sm" onClick={handleNext} className="h-7 text-xs gap-1">
                                    {currentStep === STEPS.length - 1 ? (
                                        <>Finish <Check className="w-3 h-3" /></>
                                    ) : (
                                        <>Next <ArrowRight className="w-3 h-3" /></>
                                    )}
                                </Button>
                            </div>
                        </motion.div>
                    )}
                </div>
            )}
        </AnimatePresence>
    );
}
