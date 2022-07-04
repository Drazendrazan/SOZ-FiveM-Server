import { Injectable } from '../../core/decorators/injectable';
import { wait } from '../../core/utils';

@Injectable()
export class ResourceLoader {
    async loadPtfxAsset(name: string): Promise<void> {
        if (!HasNamedPtfxAssetLoaded(name)) {
            RequestNamedPtfxAsset(name);

            while (!HasNamedPtfxAssetLoaded(name)) {
                await wait(0);
            }
        }
    }

    unloadedPtfxAsset(name: string): void {
        RemoveNamedPtfxAsset(name);
    }
}