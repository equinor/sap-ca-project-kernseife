import { Destination } from '#cds-models/kernseife/db';
import { getAllDestinationsFromDestinationService } from '@sap-cloud-sdk/connectivity';
import { entities } from '@sap/cds';

export const updateDestinations = async () => {
  await DELETE(entities.Destinations);

  const destinations = await getAllDestinationsFromDestinationService();

  await INSERT.into(entities.Destinations).entries(
    destinations
      .filter(
        (destination) =>
          destination.name != 'ui5' &&
          !destination.name?.endsWith('-html5-repo-host') &&
          !destination.name?.endsWith('-srv') &&
          !destination.name?.endsWith('-auth')
      )
      .map(
        (destination) =>
          ({
            name: destination.name,
            type: destination.type,
            authentication: destination.authentication,
            proxyType: destination.proxyType
          }) as Destination
      )
  );
};
