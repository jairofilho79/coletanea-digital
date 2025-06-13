import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
    name: 'classificacao'
})
export class ClassificacaoPipe implements PipeTransform {
    private readonly map: { [key: string]: string } = {
        'ColAdultos': "Coletânea de Partituras Adultos",
        'ColCIAs': "Coletânea de Partituras CIAs",
        'A': "Avulso PES",
        'DpLICM': "Departamento de Louvor ICM",
        'EL042025': "Encontro de Louvor 04/25",
        'GLGV': "Grupo de Louvor Gov. Valadares",
        'GLMUberlandia': "Grupo de Louvor do Maanaim de Uberlândia",
        'ACIA': 'Avulso CIAs',
        'PESCol': 'Novo Arranjo PES',
    };

    transform(value: string): string {
        return this.map[value] || value;
    }
}