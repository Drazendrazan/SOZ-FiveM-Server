import { Once, OnceStep } from '../../../core/decorators/event';
import { Inject } from '../../../core/decorators/injectable';
import { Provider } from '../../../core/decorators/provider';
import { ServerEvent } from '../../../shared/event';
import { PlayerService } from '../../player/player.service';
import { Qbcore } from '../../qbcore';
import { TargetFactory } from '../../target/target.factory';

@Provider()
export class BennysEstimateProvider {
    @Inject(PlayerService)
    private playerService: PlayerService;

    @Inject(TargetFactory)
    private targetFactory: TargetFactory;

    @Inject(Qbcore)
    private QBCore: Qbcore;

    @Once(OnceStep.Start)
    public async onStart() {
        this.targetFactory.createForAllVehicle([
            {
                label: 'Estimer',
                icon: 'c:bennys/estimate.png',
                job: 'bennys',
                canInteract: () => {
                    return this.playerService.isOnDuty();
                },
                action: async vehicle => {
                    if (!this.playerService.isOnDuty() || !this.QBCore.hasJobPermission('bennys', 'estimate')) {
                        return;
                    }
                    const properties = this.QBCore.getVehicleProperties(vehicle);
                    const networkId = NetworkGetNetworkIdFromEntity(vehicle);

                    TriggerServerEvent(ServerEvent.BENNYS_ESTIMATE_VEHICLE, networkId, properties);
                },
            },
        ]);
    }
}