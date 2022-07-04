import { SozRole } from '../permissions';
import { setMethodMetadata } from './reflect';

export type CommandMetadata = {
    name: string;
    description: string;
    role?: SozRole;
};

export const CommandMetadataKey = 'soz_core.decorator.command';

export const Command = (name: string, options: Partial<Omit<CommandMetadata, 'name'>> = {}): MethodDecorator => {
    return (target, propertyKey) => {
        setMethodMetadata(
            CommandMetadataKey,
            {
                name,
                description: options.description || null,
                role: options.role || null,
            },
            target,
            propertyKey
        );
    };
};