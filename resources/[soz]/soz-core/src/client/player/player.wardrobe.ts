import { OnEvent, OnNuiEvent } from '../../core/decorators/event';
import { Inject } from '../../core/decorators/injectable';
import { Provider } from '../../core/decorators/provider';
import { Outfit, WardrobeConfig } from '../../shared/cloth';
import { ClientEvent, NuiEvent } from '../../shared/event';
import { MenuType } from '../../shared/nui/menu';
import { NuiMenu } from '../nui/nui.menu';

type OutfitSelection = {
    outfit: Outfit | null;
    canceled: boolean;
};

@Provider()
export class PlayerWardrobe {
    @Inject(NuiMenu)
    private nuiMenu: NuiMenu;

    private currentOutfitResolve: (outfit: OutfitSelection) => void | null;

    public async selectOutfit(config: WardrobeConfig, nullLabel?: string): Promise<OutfitSelection | null> {
        const model = GetEntityModel(PlayerPedId());
        const wardrobe = config[model];

        if (!wardrobe) {
            return null;
        }

        const promise = new Promise<OutfitSelection>(resolve => {
            this.currentOutfitResolve = resolve;
        });

        this.nuiMenu.openMenu(MenuType.Wardrobe, {
            wardrobe,
            allowNullLabel: nullLabel,
        });

        return promise;
    }

    @OnNuiEvent<Outfit>(NuiEvent.SetWardrobeOutfit)
    public async onSetWardRobeOutfit(outfit: Outfit | null) {
        if (this.currentOutfitResolve) {
            this.currentOutfitResolve({ outfit: outfit, canceled: false });
        }

        this.nuiMenu.closeMenu();
        this.currentOutfitResolve = null;

        return true;
    }

    @OnEvent(ClientEvent.CORE_CLOSE_MENU)
    public async onCloseMenu() {
        if (this.currentOutfitResolve) {
            this.currentOutfitResolve({ outfit: null, canceled: true });
        }

        this.nuiMenu.closeMenu();
        this.currentOutfitResolve = null;
    }
}