import { useGuestPredictions } from "@/providers/guest-prediction-provider";

export function useGuestPrediction() {
    return useGuestPredictions();
}
