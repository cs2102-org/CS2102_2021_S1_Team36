import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'filterspecies'
})
export class FilterspeciesPipe implements PipeTransform {

  transform(allSpecies: any, ownedSpecies: any): any {
    let difference = allSpecies.filter(x => !ownedSpecies.includes(x));
    return difference;
  }
  
}
