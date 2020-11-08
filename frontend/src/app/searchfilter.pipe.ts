import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'searchfilter'
})
export class SearchfilterPipe implements PipeTransform {

  transform(value: any, searchValue: string): any {
    if (!value || !searchValue) {
      return value;
    } else {
      return value.filter(p => 
        p.email.toLocaleLowerCase().includes(searchValue.toLocaleLowerCase()) || 
        p.name.toLocaleLowerCase().includes(searchValue.toLocaleLowerCase()) 
      );
    }
  }

}
